import * as fc from 'fast-check';

describe('Example test', () => {
  it('should pass', () => {
    expect(true).toBe(true);
  });

  // New property-based test
  it('should always return a string of the correct length', () => {
    fc.assert(
      fc.property(fc.integer({ min: 1, max: 100 }), (n) => {
        const result = 'a'.repeat(n);
        expect(result.length).toBe(n);
        expect(typeof result).toBe('string');
      }),
    );
  });
});
