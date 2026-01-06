export const throttle = <F extends (...args: any[]) => any>(
  func: F,
  limit: number,
): ((...args: Parameters<F>) => void) => {
  let throttled: boolean;
  return function (this: any, ...args: Parameters<F>) {
    if (!throttled) {
      func.apply(this, args);
      throttled = true;
      setTimeout(() => (throttled = false), limit);
    }
  };
};
